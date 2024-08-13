package fr.cristal.ioda;

import org.nlogo.api.*;
import org.nlogo.api.Command;
import org.nlogo.api.Dump;
import org.nlogo.api.Reporter;
import org.nlogo.core.*;

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
public class Assignation implements Comparable<Assignation>, ExtensionObject {
	private static long next = 0 ;

	private final long id ;
	private String source, target ;
	private Interaction interaction ;
	private double distance, priority ;
	private String targetSelectionMethod = "RANDOM" ;

	public static void clearAll() { next = 0 ; }

	public Assignation(String source, Interaction interaction, double priority, String target, double distance) {
		this.id = next ;
		next++ ;
		this.source = source.toLowerCase() ;
		this.interaction = interaction ;
		this.priority = priority ;
		this.target = target.toLowerCase()  ;
		this.distance = distance ;
	}

	public String toString() {
		String result = this.source + "\t" + this.interaction.getName() + "\t" + this.priority ;
		if (!this.isDegenerate()) {
			result = result + "\t" + this.target + "\t" + this.distance ;
			if (!this.targetSelectionMethod.equalsIgnoreCase("RANDOM"))
				result = result + "\t" + this.targetSelectionMethod ;
		}
		return result ;
	}

	public Assignation(String source, Interaction interaction, double priority) {
		this(source, interaction, priority, "nobody", 0) ;
	}

	public Assignation(LogoList l) {
		this((String)l.get(0), Interaction.get((String)l.get(1)), (Double)l.get(2)) ;
		if (l.size() > 3) {
			this.target = (String)l.get(3) ;
			this.distance = (Double)l.get(4) ;
			if (l.size() > 5)
				this.targetSelectionMethod = ((String)l.get(5)).toUpperCase() ;
		}
	}

	public void setDistance(double distance) { this.distance = distance ; }
	public void setPriority(double priority) { this.priority = priority ; }
	public void setTargetSelectionMethod(String method) { targetSelectionMethod = method ; }

	public String getTargetSelectionMethod() { return targetSelectionMethod ; }
	public String getSource() { return source ; }
	public double getPriority() { return priority ; }
	public Interaction getInteraction() { return interaction ; }
	public String getTarget() { return target ; }
	public double getDistance() { return distance ; }
	public boolean isDegenerate() { return target.equals("nobody") ; }

	public boolean equals(Object obj) { return this.recursivelyEqual(obj) ; }

	public LogoList toList() {
		LogoListBuilder aList = new LogoListBuilder() ;
		aList.add(this.getSource()) ;
		aList.add(this.getInteraction().getName()) ;
		aList.add(this.getPriority()) ;
		if (!this.isDegenerate()) {
			aList.add(this.getTarget()) ;
			aList.add(this.getDistance()) ;
			aList.add(this.targetSelectionMethod) ;
		}
		return aList.toLogoList() ;
	}

	public String dump(boolean readable, boolean exportable, boolean reference) {
		if (exportable && reference)
			return (""+id) ;
		else
			return (exportable?(id+": "):"") + Dump.logoObject(this.toList(), true, exportable) ;
	}

	public String getExtensionName() { return "ioda" ; }
	public String getNLTypeName() { return "assignation" ; }

	public boolean recursivelyEqual(Object o) {
		if (!(o instanceof Assignation))
			return false ;
		Assignation a = (Assignation) o ;
		return  ((a.isDegenerate() == this.isDegenerate()) &&
				(a.getSource().equalsIgnoreCase(this.getSource())) &&
				(a.getInteraction().equals(this.getInteraction())) &&
				(a.getPriority() == this.getPriority()) &&
				(a.getDistance() == this.getDistance()) &&
				(a.getTarget().equalsIgnoreCase(this.getTarget())) &&
				(a.getTargetSelectionMethod().equalsIgnoreCase(this.getTargetSelectionMethod()))) ;
	}

	public int compareTo(Assignation a) {
		return Double.compare(this.getPriority(), a.getPriority());
	}


	//----------------------------------------------------------------
	public static class AssignationFromList implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.ListType()}, Syntax.WildcardType());
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			return new Assignation(args[0].getList()) ;
		}
	}

	//----------------------------------------------------------------
	public static class AssignationToList implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType()}, Syntax.ListType());
		}
		public String getAgentClassString() { return "OTPL" ; }

		public Object report(Argument[] args, Context context) throws ExtensionException {
			Object arg0 = args[0].get() ;
			if (!(arg0 instanceof Assignation))
				throw new ExtensionException("Not an assignation: "+arg0) ;
			return ((Assignation)arg0).toList();
		}
	}

	//----------------------------------------------------------------
	public static class GetSourceBreed implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType()}, Syntax.AgentsetType()) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (!(arg0 instanceof Assignation))
				throw new ExtensionException("not an assignation: "+org.nlogo.api.Dump.logoObject(arg0)) ;
			Assignation a = (Assignation) arg0 ;
			String srcBreed = a.getSource() ;
			return IodaExtension.findBreedNamed(context, srcBreed) ;
		}
	}


	//----------------------------------------------------------------
	public static class GetTargetBreed implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType()}, (Syntax.AgentsetType()|Syntax.NobodyType())) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (!(arg0 instanceof Assignation))
				throw new ExtensionException("not an assignation: "+org.nlogo.api.Dump.logoObject(arg0)) ;
			Assignation a = (Assignation) arg0 ;
			String tgtBreed = a.getTarget() ;
			if (tgtBreed.equalsIgnoreCase("nobody"))
				return Nobody.class ;
			return IodaExtension.findBreedNamed(context, tgtBreed) ;
		}
	}

	//----------------------------------------------------------------
	public static class IsDegenerate implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType()}, Syntax.BooleanType()) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (!(arg0 instanceof Assignation))
				throw new ExtensionException("not an assignation: "+org.nlogo.api.Dump.logoObject(arg0)) ;
			Assignation a = (Assignation) arg0 ;
			return a.isDegenerate() ;
		}
	}

	//----------------------------------------------------------------
	public static class GetPriority implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType()}, Syntax.NumberType()) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (!(arg0 instanceof Assignation))
				throw new ExtensionException("not an assignation: "+org.nlogo.api.Dump.logoObject(arg0)) ;
			Assignation a = (Assignation) arg0 ;
			return a.getPriority() ;
		}
	}

	//----------------------------------------------------------------
	public static class GetDistance implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType()}, Syntax.NumberType()) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (!(arg0 instanceof Assignation))
				throw new ExtensionException("not an assignation: "+org.nlogo.api.Dump.logoObject(arg0)) ;
			Assignation a = (Assignation) arg0 ;
			return a.getDistance() ;
		}
	}

	//----------------------------------------------------------------
	public static class GetInteraction implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType()}, Syntax.WildcardType()) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (!(arg0 instanceof Assignation))
				throw new ExtensionException("not an assignation: "+org.nlogo.api.Dump.logoObject(arg0)) ;
			Assignation a = (Assignation) arg0 ;
			return a.getInteraction() ;
		}
	}

	//----------------------------------------------------------------
	public static class TargetSelectionMethod implements Reporter {
		public Syntax getSyntax() {
			return SyntaxJ.reporterSyntax(new int[] {Syntax.WildcardType()}, Syntax.StringType()) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public Object report(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (!(arg0 instanceof Assignation))
				throw new ExtensionException("not an assignation: "+org.nlogo.api.Dump.logoObject(arg0)) ;
			Assignation a = (Assignation) arg0 ;
			return a.getTargetSelectionMethod() ;
		}
	}

	//----------------------------------------------------------------
	public static class SetTargetSelectionMethod implements Command {
		public Syntax getSyntax() {
			return SyntaxJ.commandSyntax(new int[] {Syntax.WildcardType(), Syntax.StringType()}) ;
		}
		public String getAgentClassString() { return "OTPL" ; }
		public void perform(Argument[] args, Context context)
				throws ExtensionException, LogoException {
			Object arg0 = args[0].get() ;
			if (!(arg0 instanceof Assignation))
				throw new ExtensionException("not an assignation: "+org.nlogo.api.Dump.logoObject(arg0)) ;
			Assignation a = (Assignation) arg0 ;
			String method = args[1].getString().toUpperCase() ;
			if (!(method.equals("RANDOM") || method.equals("RANDOM-INT") || method.startsWith("BEST:")
					|| method.startsWith("ALL-BEST:") || method.startsWith("NUMBER:") || method.startsWith("PRORATA:")
					|| method.equals("ALL")) || method.startsWith("FILTER:"))
				throw new ExtensionException("not a valid target selection method: "+method+"\nValid methods are: "+
						"RANDOM, RANDOM-INT, ALL, FILTER:A_REPORTER, NUMBER:A_RANGE, BEST:A_REPORTER, ALL-BEST:A_REPORTER, PRORATA:A_REPORTER") ;
			a.setTargetSelectionMethod(method) ;
		}
	}
}
