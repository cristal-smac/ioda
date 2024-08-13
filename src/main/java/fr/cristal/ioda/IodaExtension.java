package fr.cristal.ioda;

import org.nlogo.api.*;
import org.nlogo.agent.Agent ;
import org.nlogo.agent.Turtle ;
import org.nlogo.agent.Patch ;
import org.nlogo.core.LogoList;
import org.nlogo.core.Nobody;
import org.nlogo.core.Syntax;
import org.nlogo.core.SyntaxJ;
import org.nlogo.nvm.ExtensionContext ;
import scala.collection.JavaConverters;

import java.util.Set ;
import java.util.ArrayList ;

/** <p>This class is part of the IODA NetLogo extension.<bR> All
 * contents &copy; 2008-2024 Sébastien PICAULT and Philippe
 * MATHIEU<br> Centre de Recherche en Informatique, Signal et
 * Automatique de Lille (CRIStAL), UMR CNRS 9189<br> Université de
 * Lille (Sciences et Technologies) – Cité Scientifique, F-59655
 * Villeneuve d'Ascq Cedex, FRANCE.<br> Web Site: <a
 * href="https://github.com/cristal-smac/ioda">https://github.com/cristal-smac/ioda</a></p>
 * <p>The IODA NetLogo extension is free software: you can
 * redistribute it and/or modify it under the terms of the GNU General
 * Public License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later
 * version.</p> <p>The IODA NetLogo extension is distributed in the
 * hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 * PURPOSE. See the GNU General Public License for more details.</p>
 * <p>You should have received a copy of the GNU General Public
 * License along with the IODA NetLogo extension. If not, see <a
 * href="http://www.gnu.org/licenses">http://www.gnu.org/licenses</a>.</p>
 *
 * @author Sébastien Picault
 * @author Nathan Hallez
 * @author Philippe Mathieu
 *
 * @see <a href="https://www.cristal.univ-lille.fr/SMAC/projects/ioda/index-2.html">The IODA Webpage</a>
 * @version IODA Extension 3.0 - Jul. 2024
 */
public class IodaExtension extends org.nlogo.api.DefaultClassManager {
    public void load(PrimitiveManager prim) {
	// General purpose primitives 
	prim.addPrimitive("check-consistency", new CheckConsistency()) ;
	prim.addPrimitive("clear-all", new ClearAll()) ;
 	prim.addPrimitive("get-breed-named", new GetBreedNamed()) ;
	prim.addPrimitive("primitives-to-write", new PrimitivesToWrite()) ;
 	prim.addPrimitive("version", new Version()) ;


	// primitives related to Interaction
	prim.addPrimitive("eval-condition", new Interaction.EvalCondition()) ;
	prim.addPrimitive("eval-trigger", new Interaction.EvalTrigger()) ;
	prim.addPrimitive("get-interaction", new Interaction.GetInteraction()) ;
	prim.addPrimitive("get-interactions", new Interaction.GetInteractions()) ;
	prim.addPrimitive("interaction-from-list", new Interaction.InteractionFromList()) ;
	prim.addPrimitive("interaction-make", new Interaction.InteractionMake()) ;
	prim.addPrimitive("interaction-name", new Interaction.InteractionName()) ;
	prim.addPrimitive("is-exclusive?", new Interaction.IsExclusive()) ;
	prim.addPrimitive("read-interactions", new Interaction.LoadInteractions()) ;
	prim.addPrimitive("perform-actions", new Interaction.PerformActions()) ;
	prim.addPrimitive("print-interactions", new Interaction.PrintInteractions()) ;
	prim.addPrimitive("set-exclusive", new Interaction.SetExclusive()) ;
	prim.addPrimitive("set-exclusive-interactions", new Interaction.SetExclusiveInteractions()) ;

	// primitives related to Assignation
	prim.addPrimitive("assignation-from-list", new Assignation.AssignationFromList()) ;
	prim.addPrimitive("assignation-to-list", new Assignation.AssignationToList()) ;
	prim.addPrimitive("get-distance", new Assignation.GetDistance()) ;
	prim.addPrimitive("get-interaction-of", new Assignation.GetInteraction()) ;
	prim.addPrimitive("get-priority", new Assignation.GetPriority()) ;
	prim.addPrimitive("get-source-breed", new Assignation.GetSourceBreed()) ;
	prim.addPrimitive("get-target-breed", new Assignation.GetTargetBreed()) ;
	prim.addPrimitive("is-degenerate?", new Assignation.IsDegenerate()) ;
	prim.addPrimitive("set-target-selection-method", new Assignation.SetTargetSelectionMethod()) ;
	prim.addPrimitive("target-selection-method", new Assignation.TargetSelectionMethod()) ;

	// primitives related to Interaction Matrix
	prim.addPrimitive("active-agents", new Matrix.ActiveAgents()) ;
	prim.addPrimitive("active-agents-with-targets", new Matrix.ActiveAgentsWithTargets()) ;
	prim.addPrimitive("basic-add-assignation", new Matrix.AddAssignation()) ;
	prim.addPrimitive("clear-matrices", new Matrix.ClearMatrices()) ;
	prim.addPrimitive("get-breed-targets", new Matrix.GetBreedTargets()) ;
	prim.addPrimitive("get-interaction-matrix", new Matrix.GetInteractionMatrix()) ;
	prim.addPrimitive("get-matrix-line", new Matrix.GetMatrixLine()) ;
	prim.addPrimitive("get-update-matrix", new Matrix.GetUpdateMatrix()) ;
	prim.addPrimitive("is-active?", new Matrix.IsActive()) ;
	prim.addPrimitive("is-labile?", new Matrix.IsLabile()) ;
	prim.addPrimitive("is-passive?", new Matrix.IsPassive()) ;
	prim.addPrimitive("labile-agents", new Matrix.LabileAgents()) ;
	prim.addPrimitive("read-matrices", new Matrix.LoadMatrices()) ;
	prim.addPrimitive("matrix-make", new Matrix.MatrixMake()) ;
	prim.addPrimitive("matrix-to-list", new Matrix.MatrixToList()) ;
	prim.addPrimitive("matrix-view", new Matrix.MatrixView()) ;
	prim.addPrimitive("passive-agents", new Matrix.PassiveAgents()) ;
	prim.addPrimitive("print-interaction-matrix", new Matrix.PrintInteractionMatrix()) ;
	prim.addPrimitive("print-update-matrix", new Matrix.PrintUpdateMatrix()) ;
	prim.addPrimitive("basic-remove-assignation", new Matrix.RemoveAssignation()) ;
	prim.addPrimitive("set-interaction-matrix", new Matrix.SetInteractionMatrix()) ;
	prim.addPrimitive("set-update-matrix", new Matrix.SetUpdateMatrix()) ;
    }

    public void clearAll() {
	Interaction.clearAll() ;
	Assignation.clearAll() ;
	Matrix.clearAll() ;
    }

    public static AgentSet findBreedOfCaller(Context context) {
	return findBreedOfAgent(context, (Agent)context.getAgent()) ;
    }
    
    public static AgentSet findBreedOfAgent(Context context, Agent ag) {
	if (ag instanceof Patch)
	    return  findBreedNamed(context, "patches") ;
	else 
	    return ((Turtle)ag).getBreed() ;
    }
    
    public static AgentSet findBreedNamed(Context context, String breedName) {
	if (breedName.equalsIgnoreCase("nobody"))
	    return null ;
	if ((breedName.equalsIgnoreCase("patch")) || (breedName.equalsIgnoreCase("patches")))
	    return  ((ExtensionContext)context).workspace().world().patches() ;
	if ((breedName.equalsIgnoreCase("turtle")) || (breedName.equalsIgnoreCase("turtles")))
	    return  ((ExtensionContext)context).workspace().world().turtles() ;
	else 
	    return ((ExtensionContext)context).workspace().world().getBreed(breedName.toUpperCase()) ;
    }
    
    public static boolean checkConsistency(Set<String> procedures) throws ExtensionException {
	ArrayList<ArrayList<String>> t = primitivesToWrite() ;
	for (String r: t.get(0))
	    if (!procedures.contains(r.toUpperCase()))
		throw new ExtensionException("Reporter not found: "+r.toUpperCase()) ;
	for (String c: t.get(1))
	    if (!procedures.contains(c.toUpperCase()))
		throw new ExtensionException("Command not found: "+c.toUpperCase()) ;
	return true ;
    }
    
    public static String printPrimitives(Set<String> procedures) {
	ArrayList<ArrayList<String>> t = primitivesToWrite() ;
	StringBuffer b = new StringBuffer() ;
	for (String r: t.get(0))
	    if (!procedures.contains(r.toUpperCase()))
		b.append("to-report "+r+"\nend\n\n") ;
	for (String c: t.get(1))
	    if (!procedures.contains(c.toUpperCase()))
		b.append("to "+c+"\nend\n\n") ;
	return b.toString() ;
    }
    
    public static ArrayList<ArrayList<String>> primitivesToWrite() {
	ArrayList<ArrayList<String>> primitives = new ArrayList<ArrayList<String>>() ;
	ArrayList<String> reporters = new ArrayList<String>() ;
	ArrayList<String> commands = new ArrayList<String>() ;
	ArrayList<Assignation> assign = new ArrayList<Assignation>() ;
	for (Object o : Matrix.activeBreedsWithTargets().toJava()) {
		AgentSet s = (AgentSet) o;
		commands.add(s.printName().toLowerCase() + "::" + "filter-neighbors");
	}
	for (Assignation a: Matrix.interactionMatrix.collectAssignations())
	    if (!assign.contains(a))
		assign.add(a) ;
	for (Assignation a: Matrix.updateMatrix.collectAssignations())
	    if (!assign.contains(a))
		assign.add(a) ;
	for (Assignation a: assign) {
	    Interaction i = a.getInteraction() ;
	    String sourceBreed = a.getSource() ;
	    String targetBreed = a.getTarget() ;
	    String method = a.getTargetSelectionMethod() ;
	    String name = "" ;
	    ArrayList<Object> l = new ArrayList<Object>() ;
	    l.addAll(i.getTrigger().toJava()) ;
	    l.addAll(i.getCondition().toJava()) ;
	    for (Object reps : l) {
		LogoList lreps = (LogoList) reps ;
		for (Object rep: lreps.toJava()) {
		    String reporter = (String) rep ;
		    if (reporter.startsWith("not:")) // 2.3 addition
			reporter = reporter.substring(4) ; // 2.3 addition
		    if (reporter.startsWith("target:")) {
			if (!targetBreed.equals("nobody")) {
			    reporter = reporter.substring(7) ;
			    if (reporter.startsWith("not:")) // 2.3 addition
				reporter = reporter.substring(4) ; // 2.3 addition
			    name = targetBreed+"::"+reporter ;
			    if (!reporters.contains(name))
				reporters.add(name) ;
			}
		    } else {
			name = sourceBreed+"::"+reporter ;
			if (!reporters.contains(name))
			    reporters.add(name) ;
		    }
		}
	    }
	    if ((method.startsWith("PRORATA:")) || (method.startsWith("BEST:")) || (method.startsWith("ALL-BEST:"))) 
		if (!targetBreed.equals("nobody")) {
		    name = targetBreed + "::" + method.substring(method.indexOf(':')+1).toLowerCase() ;
		    if (!reporters.contains(name))
			reporters.add(name) ;
		}
	    if ((method.startsWith("FILTER:")))
		if (!targetBreed.equals("nobody")) {
		    name = sourceBreed + "::" + method.substring(method.indexOf(':')+1).toLowerCase() ;
		    if (!reporters.contains(name))
			reporters.add(name) ;
		}
	    l.clear() ;
	    l.addAll(i.getActions().toJava()) ;
	    for (Object comd : l) {
		String command = (String) comd ;
		if (command.startsWith("target:")) {
		    if (!targetBreed.equals("nobody")) {
			command = command.substring(7) ;
			name = targetBreed+"::"+command ;
			if (!commands.contains(name))
			    commands.add(name) ;
		    }
		} else {
		    name = sourceBreed+"::"+command ;
		    if (!commands.contains(name))
			commands.add(name) ;
		}
	    }
	}
	primitives.add(reporters) ;
	primitives.add(commands) ;
	return primitives ;
    }
    
    //----------------------------------------------------------------
    public static class Version implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.StringType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument[] args, Context context)
	    throws ExtensionException, LogoException {
	    return "3.0" ;
	}
    }

    //----------------------------------------------------------------
    public static class GetBreedNamed implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {Syntax.StringType()}, Syntax.AgentsetType()|Syntax.NobodyType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument[] args, Context context)
	    throws ExtensionException, LogoException {
	    AgentSet b = findBreedNamed(context, args[0].getString()) ;
	    if (b == null)
		return Nobody.class ;
	    return b ;
	}
    }

    //----------------------------------------------------------------
    public static class CheckConsistency implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.BooleanType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument[] args, Context context)
	    throws ExtensionException, LogoException {
	    return checkConsistency(JavaConverters.setAsJavaSet(((ExtensionContext)context).workspace().procedures().keySet()));
	}
    }

    //----------------------------------------------------------------
    public static class PrimitivesToWrite implements Reporter {
	public Syntax getSyntax() {
	    return SyntaxJ.reporterSyntax(new int[] {}, Syntax.StringType()) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public Object report(Argument[] args, Context context)
	    throws ExtensionException, LogoException {
	    return printPrimitives(JavaConverters.setAsJavaSet(((ExtensionContext)context).workspace().procedures().keySet()));
	}
    }

    //----------------------------------------------------------------
    public static class ClearAll implements Command {
	public Syntax getSyntax() {
	    return SyntaxJ.commandSyntax(new int[] {}) ;
	}
	public String getAgentClassString() { return "OTPL" ; }
	public void perform(Argument[] args, Context context){
	    Interaction.clearAll() ;
	    Assignation.clearAll() ;
	    Matrix.clearAll() ;
	}
    }}
